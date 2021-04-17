module SlowFat
  class FileAllocationTable
    attr_reader :chains, :base, :size

    def initialize(backing:, base:, size:)
      @backing = backing
      @base = base
      @size = size
    end

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