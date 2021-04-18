module SlowFat
  class Filesystem
    attr_reader :backing, :rootdir_base, :rootdir, :data_base, :fats, :cluster_size

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

    def bootsect
      @backing.seek @base
      BootSector.new @backing.read(512)
    end

    def bios_parameter_block
      bootsect.bios_parameter_block
    end

    def extended_bios_parameter_block
      bootsect.extended_bios_parameter_block
    end

    def dir(dirname)
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

    def file(path)
      path_components = path.split('/')
      dir_components = path_components[0..-2]
      filename = path_components[-1]
      dentry = dir(dir_components.join('/')).file_entry(filename)
      FatFile.new filesystem: self, dentry: dentry
    end
  end
end
