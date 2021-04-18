module SlowFat
  ##
  # BootSector handles accessing information inside the boot sector, such as BPB, signature, and boot code.
  class BootSector
    # @return [String] the OEM Name contained in this boot sector.
    attr_reader :oem_name

    ##
    # DataError is raised if unexpected data is encountered when handling the filesystem.
    class DataError < StandardError
    end

    ##
    # Initialize a new BootSector object (normally only called from Filesystem)
    # @param data [String] raw data making up this boot sector
    def initialize(data)
      (@jmp, @oem_name, @bpb, @ebpb, @boot_code, @boot_signature) = data.unpack('a3a8a25a26a448v')
      raise DataError, "Invalid boot signature in boot sector." if(@boot_signature != 0xAA55)
    end

    ##
    # Parse out and return a BIOS Parameter Block from this boot sector
    # @return [BiosParameterBlock] the BPB parsed out of this boot sector
    def bios_parameter_block
      BiosParameterBlock.new @bpb
    end

    ##
    # Parse out and return an Extended BIOS Parameter Block from this boot sector
    # @return [ExtendedBiosParameterBlock] the EBPB parsed out of this boot sector
    def extended_bios_parameter_block
      ExtendedBiosParameterBlock.new @ebpb
    end
  end

  ##
  # BiosParameterBlock holds information from a BPB.
  class BiosParameterBlock
    attr_reader :bytes_per_logsect, :logsects_per_cluster, :reserved_logsects, :fats, :root_entries, :logsects, :media_descriptor, :logsects_per_fat, :physects_per_track, :heads, :hidden_logsects, :large_total_logsects

    def initialize(data)
      (@bytes_per_logsect, @logsects_per_cluster, @reserved_logsects, @fats, @root_entries, @total_logsects, @media_descriptor, @logsects_per_fat, @physects_per_track, @heads, @hidden_logsects, @large_total_logsects) = data.unpack('vCvCvvCvvvVV')
    end

    ##
    # Return the type of media this boot sector is on
    # @return [Symbol] the type of media described by the media descriptor in the boot sector
    def media_descriptor_type
      case @media_descriptor_id
        when 0xE5
          :floppy_8inch
        when 0xF0
          :floppy_35inch_hd
        when 0xF8
          :fixed_disk
        when 0xFD
          :floppy_525inch_ld
        else
          :unknown
      end
    end
  end
  
  ##
  # ExtendedBiosParameterBlock holds information from an EBPB.
  class ExtendedBiosParameterBlock
    attr_reader :physical_drive_nbr, :boot_signature, :volume_serial, :volume_label, :fs_type

    def initialize(data)
      (@physical_drive_nbr, @flags, @boot_signature, @volume_serial, @volume_label, @fs_type) = data.unpack('CCCVa11a8')
    end
  end
end