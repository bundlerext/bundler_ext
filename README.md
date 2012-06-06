bundler_ext
===========

Simple library leveraging the Bundler Gemfile DSL to load gems already on the 
system and managed by the systems package manager (like yum/apt).

The purpose of this library is to allow, for instance, yum and rpm to manage the 
dependencies for a project, and simply reuse the Gemfile to get the list of directly
required gems for (in initial use case) a Rails 3.x application. It would be useful in
such cases for there to be a big switch in Bundler that woudl allow the user to tell it
'You are allevaiated of the responsibility of resolving dependencies, that has been
taken care of for you. This is the use case for many linux systems, and this library
is an initial attempt to get the two approaches to no step on each other.

Example usage:

  Aeolus::Ext::BundlerExt.system_require(File.expand_path('../../Gemfile.in', __FILE__),:default, Rails.env)

You may also want to wrap your call in some kind of check, to allow non-platform users
(ie, mac, or any developer not installing as a sysadmin) to still use bunlder if they 
want to.  One example would be to set an env var, something like:

  export USE_BUNDLER=yes

Then, if that is not set, look for a Gemfile, otherwise, load deps via Gemfile.in.

Note there is a reason for the 2 files names (for now at least) - Some libraries, like
Rspec, Cucumber, even Rails, try to be smart and load up via Bunlder themselves if they
see a Gemfile in the working directory.  In the linux deployment case, this is not the
desired behavior, we explicitly want to say 'just use what the package manager has
installed'.
