require 'omf_rc'

module OmfRc::ResourceProxy::Board
  include OmfRc::ResourceProxyDSL

  register_proxy :board


  hook :after_create do |board, netfpga|
    info "Netfpga #{netfpga.uid} created"
  end
end

module OmfRc::ResourceProxy::Netfpga
  include OmfRc::ResourceProxyDSL

  register_proxy :netfpga, :create_by => :board

  property :serial_number, :default => "0000"
  property :referenceName, :default => "Selftest"
  property :referencePath, :default => "/root/netfpga/bitfiles/selftest.bit"
  property :projectPath, :default => "/root/netfpga/projects/selftest"
  property :action, :default=>"none"


  hook :before_ready do |netfpga|
  info "Netfpga serial number is #{netfpga.property.serial_number}"
  info "Netfpga reference name is #{netfpga.property.referenceName}"
  info "Netfpga reference path is #{netfpga.property.referencePath}"
  info "Netfpga project path is #{netfpga.property.projectPath}"
  info "Netfpga action is #{netfpga.property.action}"
  end

  hook :after_initial_configured do |netfpga|
    if netfpga.property.action=="simtest"
      system "export NF_DESIGN_DIR=#{netfpga.property.projectPath} && nf_run_test.pl -major nic -minor short >> /root/teste/saida.txt"
      info "Teste feito"
    end
    if netfpga.property.action=="regress"
      system "export NF_DESIGN_DIR=#{netfpga.property.projectPath}"
      system "nf_download #{netfpga.property.referencePath}"
      system "/netfpga/bin/nf_regress_test.pl" 
  end
end

OmfCommon.init(:development, communication: { url: 'amqp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Board controler >> Connected to AMQP server"
    board = OmfRc::ResourceFactory.create(:board, uid: 'board')
    comm.on_interrupted { board.disconnect }
  end
end
