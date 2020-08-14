require "test_helper"
require 'fileutils'

class FileTreeTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FileTree::VERSION
  end

  def test_new_tree
    # with last slash or not, both type new same result
    ['./test/root/', './test/root'].each do |dir_name|
      tree = ::FileTree.new(dir_name)

      assert_equal Pathname.new(dir_name), tree.root_path
      assert_equal 2, tree.nodes.size

      # [] access to nodes
      subdir1_node = tree['subdir1']
      subdir2_node = tree[:subdir2] # symbol is ok, too.

      # dir node
      assert subdir1_node.is_a?(::FileTree::Node)
      assert subdir2_node.is_a?(::FileTree::Node)
      assert subdir2_node.dir?
      refute subdir2_node.file?
      assert_equal 'subdir2', subdir2_node.basename
      assert 2, subdir2_node.children.size

      file1_node = tree[:subdir1][:file1]

      # file node
      assert file1_node.is_a?(::FileTree::Node)
      assert file1_node.file?
      refute file1_node.dir?
      assert_equal 'file1', file1_node.basename
      assert file1_node.children.empty?
    end
  end

  def test_new_tree_it_is_error_if_not_dir_is_presented
    exception = assert_raises(ArgumentError) {
      ::FileTree.new('./test/root/subdir1/file1')
    }
    assert_equal(
      './test/root/subdir1/file1 is not exist or not a directory.',
      exception.message
    )
  end

  def test_new_tree_it_is_error_if_dir_is_not_exist
    exception = assert_raises(ArgumentError) {
      ::FileTree.new('./test/not_exist_dir')
    }
    assert_equal(
      './test/not_exist_dir is not exist or not a directory.',
      exception.message
    )
  end

  def test_file_paths_it_array_of_pathname
    tree = ::FileTree.new('./test')
    file_paths = tree.file_paths

    assert file_paths.is_a?(Array)
    assert file_paths.all? { |path| path.is_a?(Pathname) }
    assert file_paths.all? { |path| FileTest.exist?(Pathname.new('./test').join(path)) }
    assert file_paths.none? { |path| FileTest.directory?(Pathname.new('./test').join(path)) }
  end

  def test_access_by_square_bracket
    tree = ::FileTree.new('./test/root')
    assert tree['subdir1']['subsubdir1'].is_a?(::FileTree::Node)
    # can use symbol
    assert_equal tree['subdir1']['subsubdir1'], tree[:subdir1][:subsubdir1]
  end

  def test_use_case_diff
    tree1 = ::FileTree.new('./test/root/subdir1')
    tree2 = ::FileTree.new('./test/root/subdir2')

    # diff 2 file trees
    files_only_in_tree1 = tree1.file_paths - tree2.file_paths
    files_only_in_tree2 = tree2.file_paths - tree1.file_paths

    assert_equal([
      Pathname.new('subsubdir1/file3'),
      Pathname.new('file2'),
    ], files_only_in_tree1)

    assert_equal([
      Pathname.new('file3'),
    ], files_only_in_tree2)

    # sync 1 tree -> 2 tree
    begin
      files_only_in_tree1.each do |file_path|
        src = tree1.root_path.join(file_path)
        dst = tree2.root_path.join(file_path)

        FileUtils.mkdir_p(File.dirname(dst))

        FileUtils.cp(src, dst)
      end
    rescue => e
      assert false, e.message
    ensure
      FileUtils.rm_r(tree2.root_path.join('subsubdir1'))
      FileUtils.rm_r(tree2.root_path.join('file2'))
    end
  end
end
