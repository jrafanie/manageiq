class GuestDevice < ApplicationRecord
  belongs_to :hardware

  has_one :vm_or_template,  :through => :hardware
  has_one :vm,              :through => :hardware
  has_one :miq_template,    :through => :hardware
  has_one :host,            :through => :hardware
  has_one :computer_system, :through => :hardware

  belongs_to :switch    # pNICs link to one switch
  belongs_to :lan       # vNICs link to one lan

  has_one :network, :foreign_key => "device_id", :dependent => :destroy, :inverse_of => :guest_device
  has_many :miq_scsi_targets, :dependent => :destroy

  has_many :firmwares, :dependent => :destroy
  has_many :child_devices, -> { where(:parent_device_id => ids) }, :foreign_key => "parent_device_id", :class_name => "GuestDevice", :dependent => :destroy

  has_many :physical_network_ports, :dependent => :destroy
  has_many :connected_physical_switches, :through => :physical_network_ports

  alias_attribute :name, :device_name

  acts_as_miq_taggable

  # A performance improvement was introduced in Rails 6:
  #
  #   https://github.com/rails/rails/commit/cc2d614e
  #
  # Causes the `present` column in this class to raise the following error:
  #
  #   ActiveRecord::DangerousAttributeError:
  #     present? is defined by Active Record. Check to make sure that you don't
  #     have an attribute or method with the same name.
  #
  # Since there is no whitelist for this method, this attempts to circumvent
  # that autogenerated error to allow our previously named column to still work
  # properly.
  #
  def self.dangerous_attribute_method?(name)
    return if name == "present?"

    super
  end

  def self.with_ethernet_type
    where(:device_type => "ethernet")
  end

  def self.with_storage_type
    where(:device_type => "storage")
  end

  def self.display_name(number = 1)
    n_('Guest Device', 'Guest Devices', number)
  end
end
