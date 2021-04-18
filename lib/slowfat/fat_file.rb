module SlowFat
  ##
  # FatFile represents a single file on a FAT filesystem
  class FatFile
    ##
    # Initialize a new Directory object (normally only called from Directory's functions)
    # @param filesystem [Filesystem] the filesystem containing this file
    # @param dentry [Dentry] the directory entry pointing to this file
    def initialize(filesystem:, dentry:)
      @filesystem = filesystem
      @dentry = dentry
      @data = Data.new(backing: filesystem.backing, base: filesystem.data_base, cluster_size: filesystem.cluster_size)
    end

    ##
    # Return the entire contents of a file
    # @return [String] the contents of this file
    def contents
      @data.cluster_chain_contents chain: @filesystem.fats[0].chain_starting_at(@dentry.start_cluster), size: @dentry.size
    end
  end
end
