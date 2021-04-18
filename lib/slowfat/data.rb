module SlowFat
  ##
  # Data is used to access the actual contents of FAT clusters.
  class Data
    ##
    # Initialize a new Data object (normally only called from FatFile)
    # @param backing [IO] the storage containing the filesystem (e.g. open file)
    # @param base [Integer] the start of the data area within the backing
    # @param cluster_size [Integer] the size of each cluster in the filesystem
    def initialize(backing:, base:, cluster_size:)
      @backing = backing
      @base = base
      @cluster_size = cluster_size
    end

    ##
    # Return the contents of a given cluster.
    # @param cluster [Integer] the cluster number to obtain data from
    # @param size [Integer] the size of data to obtain
    # @return [String] the data obtained from the given cluster
    def cluster_contents(cluster:, size:)
      @backing.seek @base + @cluster_size * cluster
      @backing.read size
    end

    ##
    # Return the contents of all clusters in given chain
    # @param chain [Integer] the chain of clusters to obtain data from
    # @param size [Integer] the total size of data to obtain
    def cluster_chain_contents(chain:, size:)
      data = ""
      chain.each_index do |idx|
        cluster = chain[idx]
        # read the whole cluster by default
        read_size = @cluster_size
        # on the last cluster of the file, read only as many
        # bytes as we need to get the rest of the file, skip the padding
        read_size = size % @cluster_size if idx == chain.length-1
        data += cluster_contents(cluster: cluster, size: read_size)
      end
      data
    end
  end
end
