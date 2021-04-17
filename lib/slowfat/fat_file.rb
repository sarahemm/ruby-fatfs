module SlowFat
  class FatFile
    def initialize(filesystem:, dentry:)
      @filesystem = filesystem
      @dentry = dentry
      @data = Data.new(backing: filesystem.backing, base: filesystem.data_base, cluster_size: filesystem.cluster_size)
    end

    def contents
      @data.cluster_chain_contents chain: @filesystem.fats[0].chain_starting_at(@dentry.start_cluster), size: @dentry.size
    end
  end
end
