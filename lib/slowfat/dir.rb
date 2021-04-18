module SlowFat
  ##
  # Directory represents one directory on a FAT filesystem.
  class Directory
    # @return [Array<Dentry>] an array of directory entries within this directory
    attr_reader :entries

    ##
    # Initialize a new Directory object (normally only called from Filesystem.dir)
    # @param backing [IO] the storage containing the filesystem (e.g. open file)
    # @param base [Integer] the location of the beginning of this directory structure within the backing device
    # @param max_entries [Integer] the maximum number of entries that can be in this directory
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

    ##
    # Return a directory entry for a specific file within this directory
    # @param filename [String] the name of the file to access
    # @return [Dentry] the directory entry object matching the requested file
    def file_entry(filename)
      @entries.each do |dentry|
        full_dentry_filename = dentry.extension.length > 0 ? "#{dentry.filename}.#{dentry.extension}".downcase : dentry.filename.downcase
        return dentry if dentry.type == :file and filename.downcase == full_dentry_filename
      end

      nil
    end

    ##
    # Return a directory entry for a specific subdirectory within this directory
    # @param filename [String] the name of the directory to access
    # @return [Dentry] the directory entry object matching the requested subdirectory
    def dir_entry(filename)
      @entries.each do |dentry|
        full_dentry_filename = dentry.extension.length > 0 ? "#{dentry.filename}.#{dentry.extension}".downcase : dentry.filename.downcase
        return dentry if dentry.type == :directory and filename.downcase == full_dentry_filename
      end

      nil
    end

    ##
    # Convert a Directory into a vaguely DOS-style file listing
    # @return [String] the contents of this directory, formatted as a human-readable listing
    def to_s
      buf = ""
      @entries.each do |dentry|
        if(dentry.type == :file) then
          buf += sprintf("%-8s %-3s   %d\n", dentry.filename, dentry.extension, dentry.size)
        elsif(dentry.type == :directory)
          buf += sprintf("%-8s %-3s   <DIR>\n", dentry.filename, dentry.extension)
        end
      end

      buf
    end

    ##
    # Dentry represents one entry inside a Directory.
    class Dentry
       # @return [String] the name of the file or other directory entry
      attr_reader :filename
      # @return [String] the file extension
      attr_reader :extension
      # @return [Integer] the starting cluster of this file in the backing
      attr_reader :start_cluster
      # @return [Integer] the size of the file in bytes
      attr_reader :size
      # @return [Symbol] the type of item this dentry describes
      attr_reader :type

      ##
      # Initialize a new directory entry (normally only called from Directory)
      # @param dir_data [String] the data making up this dentry in the backing
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

      ##
      # Returns true if this dentry has the read only attribute set
      def read_only?
        @read_only
      end

      ##
      # Returns true if this dentry has the hidden attribute set
      def hidden?
        @hidden
      end

      ##
      # Returns true if this dentry has the system attribute set
      def system?
        @system
      end
      
      ##
      # Returns true if this dentry has the archive attribute set
      def archive?
        @archive
      end

      ##
      # Returns true if this dentry has the device attribute set
      def device?
        @device
      end

      ##
      # Returns true if this dentry is a file that has been deleted
      def deleted?
        @deleted
      end

      ##
      # Returns true if this dentry is a dot directory (. or ..)
      def dotdir?
        @dotdir
      end
    end
  end
end
