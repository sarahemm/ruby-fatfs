module SlowFat
  ##
  # FileAllocationTable represents one FAT (of two on a disk, most commonly)
  class FileAllocationTable
    attr_reader :chains, :base, :size

    ##
    # Initialize a new FileAllocatinTable object (normally only called from Filesystem)
    # @param backing [IO] the storage containing the filesystem (e.g. open file)
    # @param base [Integer] the location of the beginning of this FAT structure within the backing device
    # @param size [Integer] the total size of this FAT
    def initialize(backing:, base:, size:)
      @backing = backing
      @base = base
      @size = size
    end

    ##
    # Retrieve a full chain of cluster numbers, starting at a given cluster
    # @param start_cluster [Integer] the cluster number to retrieve a chain starting from
    # @return [Array<Integer>] a list of clusters in the chain, starting from the cluster provided
    def chain_starting_at(start_cluster)
      current_cluster = start_cluster
      current_chain = []
      while current_cluster < @size/2
        @backing.seek base + current_cluster * 2
        (next_cluster, junk) = @backing.read(2).unpack('v')
        if(current_cluster+1 == size/2) then
          #printf("current: 0x%02X next: FAT END\n", current_cluster)
          current_chain << current_cluster
          return current_chain == [] ? [start_cluster] : current_chain
        elsif(next_cluster >= 0xFFF8 and next_cluster <= 0xFFFF) then
          # end of cluster marker
          #printf("current: 0x%02X next: EOC (0x%02X)\n", current_cluster, current_cluster+1)
          current_chain << current_cluster
          return current_chain == [] ? [start_cluster] : current_chain
        elsif(next_cluster == 0x0000) then
          #printf("current: 0x%02X next: FREE (0x%02X)\n", current_cluster, current_cluster+1)
          current_cluster = current_cluster + 1
        else
          # link to next cluster
          #printf("current: 0x%02X next: 0x%02X\n", current_cluster, next_cluster)
          current_chain << current_cluster
          current_cluster = next_cluster
        end
      end
    end
  end
end