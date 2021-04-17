module SlowFat
  class BootSector
    attr_reader :oem_name

    class DataError < StandardError
    end

    def initialize(data)
      (@jmp, @oem_name, @bpb, @ebpb, @boot_code, @boot_signature) = data.unpack('a3a8a25a26a448v')
      raise DataError, "Invalid boot signature in boot sector." if(@boot_signature != 0xAA55)
    end

    def bios_parameter_block
      BiosParameterBlock.new @bpb
    end

    def extended_bios_parameter_block
      ExtendedBiosParameterBlock.new @ebpb
    end
  end

  class BiosParameterBlock
    attr_reader :bytes_per_logsect, :logsects_per_cluster, :reserved_logsects, :fats, :root_entries, :logsects, :media_descriptor, :logsects_per_fat, :physects_per_track, :heads, :hidden_logsects, :large_total_logsects

    def initialize(data)
      (@bytes_per_logsect, @logsects_per_cluster, @reserved_logsects, @fats, @root_entries, @total_logsects, @media_descriptor, @logsects_per_fat, @physects_per_track, @heads, @hidden_logsects, @large_total_logsects) = data.unpack('vCvCvvCvvvVV')
    end

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
  
  class ExtendedBiosParameterBlock
    attr_reader :physical_drive_nbr, :boot_signature, :volume_serial, :volume_label, :fs_type

    def initialize(data)
      (@physical_drive_nbr, @flags, @boot_signature, @volume_serial, @volume_label, @fs_type) = data.unpack('CCCVa11a8')
    end
  end
end