require 'omf_common'

def create_netfpga(board)
  board.create(:netfpga, hrn: 'my_netpga', serial_number: '001', referenceName: "Crypto NIC", referencePath: '/root/netfpga/bitfiles/crypto_nic.bit',
    projectPath: '/root/netfpga/projects/crypto_nic', action: 'simtest') do |reply_msg|

    if reply_msg.success?
      # Since we need to interact with engine's PubSub topic,
      # we call #resource method to construct a topic from the FRCP message content.
      #
      netfpga = reply_msg.resource

      # Because of the asynchronous nature, we need to use this on_subscribed callback
      # to make sure the operation in the block executed only when subscribed to the newly created engine's topic
      netfpga.on_subscribed do
        info ">>> Connected to newly created netfpga #{reply_msg[:hrn]}(id: #{reply_msg[:res_id]})"
      end

      OmfCommon.eventloop.after(30) do
        release_netfpga(board, netfpga)
      end
    else
      error ">>> Resource creation failed - #{reply_msg[:reason]}"
    end
  end
end

def release_netfpga(board, netfpga)
  info ">>> Release netfpga"
  board.release(netfpga) do |reply_msg|
    info "Netfpga #{reply_msg[:res_id]} released"
    OmfCommon.comm.disconnect
  end
end

OmfCommon.init(:development, communication: { url: 'amqp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Netfpga test script >> Connected to AMQP"

    comm.subscribe('board') do |board|
      unless board.error?
        create_netfpga(board)
      else
        error board.inspect
      end
    end

    OmfCommon.eventloop.after(40) { comm.disconnect }
    comm.on_interrupted { comm.disconnect }
  end
end