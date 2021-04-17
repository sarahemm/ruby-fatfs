module SlowFat
  class Data
    attr_reader :base, :size

    def initialize(backing:, base:, cluster_size:)
      @backing = backing
      @base = base
      @cluster_size = cluster_size
    end

    def cluster_contents(cluster:, size:)
      @backing.seek @base + @cluster_size * cluster
      @backing.read size
    end

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
