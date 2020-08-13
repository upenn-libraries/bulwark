# Wrapper around ruby-git library that provides support for additional git commands
# needed by this application. In addition to supporting regular git command, supports
# git-annex commands and other commands needed by this application.
#
# This library requires git AND git-annex to be installed.
#
# See https://github.com/ruby-git/ruby-git for more documentation on ruby-git.
module ExtendedGit
  # (see Git.clone)
  def self.clone(repository, name, options = {})
    Base.new(Git.clone(repository, name, options))
  end

  # (see Git.bare)
  def self.init(git_dir, options = {})
    Base.new(Git.init(git_dir, options))
  end

  # (see Git.open)
  def self.open(working_dir, options = {})
    Base.new(Git.open(working_dir, options))
  end

  # Returns true if directory is a working directory.
  def self.is_working_directory?(directory)
    output, _status = Open3.capture2e(
      "git -C #{directory} rev-parse --is-inside-work-tree"
    )
    output.strip == 'true'
  end

  # Returns true if the given directory is a git directory.
  def self.is_git_directory?(directory)
    output, _status = Open3.capture2e(
      "git -C #{directory} rev-parse --is-inside-git-dir"
    )
    output.strip == 'true'
  end

  # Returns true if git-annex is installed.
  #
  # @return [Boolean]
  def self.git_annex_installed?
    begin
      ExtendedGit::AnnexLib.new.version
    rescue
      return false
    end

    true
  end
end
