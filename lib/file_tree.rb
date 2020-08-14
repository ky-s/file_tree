# frozen_string_literal: true
require 'forwardable'
require 'file_tree/version'
require 'file_tree/node'

class FileTree
  extend Forwardable
  def_delegator :@root, :[]
  def_delegator :@root, :path, :root_path
  def_delegator :@root, :children, :nodes

  def initialize(root_path)
    Dir.exist?(root_path) or
      raise ArgumentError, "#{root_path} is not exist or not a directory."

    @root = Node.new(root_path)
  end

  def file_paths # are not include above root_path.
    nodes.flat_map(&:file_paths)
  end
end
