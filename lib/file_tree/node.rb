require 'pathname'

class FileTree
  class Node
    attr_reader :path, :children

    def initialize(path)
      @path     = Pathname.new(path)
      @children = make_tree
    end

    def basename
      File.basename(@path)
    end

    # list file path
    #   not including directory node
    def file_paths
      file? and return [Pathname.new(basename)]

      @children.flat_map(&:file_paths).
        map { |path| Pathname.new(basename).join(path) }
    end

    def dir?
      FileTest.directory?(@path)
    end

    def file?
      !dir?
    end

    def [](basename)
      @children.detect { |child| child.basename == basename.to_s }
    end

    private

    def make_tree
      Dir.glob( @path.join('*') ).map do |dir_or_file|
        Node.new(dir_or_file)
      end
    end
  end
end
