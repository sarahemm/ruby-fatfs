##
# The SlowFat module handles the entire filesystem access process.
module SlowFat
  ##
  # Filesystem coordinates overall FAT filesystem access.
  class Filesystem
    # @return [IO] the backing IO object for this filesystem
    attr_reader :backing
    # @return [Integer] the location where the root directory information starts within the backing
    attr_reader :rootdir_base
    # @return [Directory] the Directory object containing the root directory
    attr_reader :rootdir
    # @return [Integer] the location where the data starts within the backing
    attr_reader :data_base
    # @return [Array<FileAllocationTable>] array of file allocation tables
    attr_reader :fats
    # @return [Integer] the cluster size used on this filesystem
    attr_reader :cluster_size

    ##
    # Set up a new filesystem connection
    # @param backing [IO] the storage containing the filesystem (e.g. open file)
    # @param base [Integer] the start of the filesystem within the backing device
    def initialize(backing:, base: 0x0000)
      @backing = backing
      @base = base

      fat_base = @base + 512
      fat_size = bios_parameter_block.bytes_per_logsect * bios_parameter_block.logsects_per_fat
      # TODO: shouldn't assume there's always two FATs
      @fats = []
      @fats[0] = FileAllocationTable.new(backing: backing, base: fat_base, size: fat_size)
      @fats[1] = FileAllocationTable.new(backing: backing, base: fat_base + fat_size, size: fat_size)

      # TODO: maybe shouldn't load the whole rootdir by default, I/O-wise?
      @rootdir_base = fat_base + fat_size*2
      @rootdir = Directory.new(backing: backing, base: rootdir_base, max_entries: bios_parameter_block.root_entries)
      @cluster_size = bios_parameter_block.bytes_per_logsect * bios_parameter_block.logsects_per_cluster
      @data_base = rootdir_base + bios_parameter_block.root_entries * 32 - @cluster_size*2
    end

    ##
    # Access the boot sector of this filesystem.
    # @return [BootSector] the boot sector on this filesystem
    def bootsect
      @backing.seek @base
      BootSector.new @backing.read(512)
    end

    ##
    # Access the BIOS Parameter Block of this filesystem.
    # @return [BiosParameterBlock] the BPB on this filesystem
    def bios_parameter_block
      bootsect.bios_parameter_block
    end

    ##
    # Access the Extended BIOS Parameter Block of this filesystem.
    # @return [ExtendedBiosParameterBlock] the EBPB on this filesystem
    def extended_bios_parameter_block
      bootsect.extended_bios_parameter_block
    end

    ##
    # Access a directory within this filesystem.
    # @param dirname [String] the path to retrieve a directory object for
    # @return [Directory] the directory object matching the requested path
    def dir(dirname)
      # TODO: accept either / or \
      path_elements = dirname.split('/')
      current_dir_base = @rootdir_base
      next_dir = nil
      max_entries = 32
      path_elements.each do |path_element|
        this_dir = Directory.new(backing: @backing, base: current_dir_base, max_entries: max_entries)
        next_dir = this_dir.dir_entry(path_element)
        return nil if next_dir == nil
        next_dir_base = @data_base + next_dir.start_cluster*@cluster_size
        # all directories except the root have more entries available
        max_entries = @cluster_size/32
        current_dir_base = next_dir_base
      end

      Directory.new(backing: @backing, base: current_dir_base, max_entries: max_entries)
    end

    ##
    # Access a file within this filesystem
    # @param path [String] the path to retrieve a file object for
    # @return [FatFile] the file object matching the requested path
    def file(path)
      path_components = path.split('/')
      dir_components = path_components[0..-2]
      filename = path_components[-1]
      dentry = dir(dir_components.join('/')).file_entry(filename)
      FatFile.new filesystem: self, dentry: dentry
    end
  end
end
