module SlowFat
  class Directory
    attr_reader :entries

    def initialize(backing:, base:, max_entries:)
      @backing = backing
      @entries = []
      (0..max_entries-1).each do |idx|
        @backing.seek base+idx*32
        dir_data = @backing.read(32)
        entry = Dentry.new(dir_data)
        break if entry.type == :end_of_dentries
        @entries << entry
      end
    end

    def file_entry(filename)
      @entries.each do |dentry|
        full_dentry_filename = dentry.extension.length > 0 ? "#{dentry.filename}.#{dentry.extension}".downcase : dentry.filename.downcase
        return dentry if dentry.type == :file and filename.downcase == full_dentry_filename
      end

      nil
    end

    def dir_entry(filename)
      @entries.each do |dentry|
        full_dentry_filename = dentry.extension.length > 0 ? "#{dentry.filename}.#{dentry.extension}".downcase : dentry.filename.downcase
        return dentry if dentry.type == :directory and filename.downcase == full_dentry_filename
      end

      nil
    end

    class Dentry
      attr_reader :filename, :extension, :start_cluster, :size, :type

      def initialize(dir_data)
        case dir_data[0].ord
          when 0x00
            # end of directory entries
            @type = :end_of_dentries
            return
          when 0x2E
            # dot entry
            @dotdir = true
          when 0xE5
            # deleted file
            @deleted = true
        end
        (@filename, @extension, attrib_bits, reserved, mod_date, mod_time, @start_cluster, @size) = dir_data.unpack('A8A3Ca10vvvV')

        @read_only  = attrib_bits & 0x01 > 0
        @hidden     = attrib_bits & 0x02 > 0
        @system     = attrib_bits & 0x04 > 0
        @archive    = attrib_bits & 0x20 > 0
        @device     = attrib_bits & 0x40 > 0

        @type = :file
        @type = :volume_label if attrib_bits & 0x08 > 0
        @type = :directory if attrib_bits & 0x10 > 0
      end

      def read_only?
        @hidden
      end

      def hidden?
        @hidden
      end

      def system?
        @system
      end
      
      def archive?
        @archive
      end

      def device?
        @device
      end

      def deleted?
        @deleted
      end

      def dotdir?
        @dotdir
      end
    end

    def dump
      @entries.each do |dentry|
        if(dentry.type == :file) then
          printf("%-8s %-3s   %d\n", dentry.filename, dentry.extension, dentry.size)
        elsif(dentry.type == :directory)
          printf("%-8s %-3s   <DIR>\n", dentry.filename, dentry.extension)
        end
      end
    end
  end
end
