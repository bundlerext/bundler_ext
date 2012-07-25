bundler_ext
===========

Simple library leveraging the Bundler Gemfile DSL to load gems already
on the system and managed by the systems package manager
(like yum/apt).

The purpose of this library is to allow, for instance, yum and rpm to
manage the dependencies for a project, and simply reuse the Gemfile
to get the list of directly required gems for (in initial use case) a
Rails 3.x application. It would be useful in such cases for there to
be a big switch in Bundler that would allow the user to tell it 'You
are allevaiated of the responsibility of resolving dependencies, that
has been taken care of for you. Understandably, since Bundler's
primary goal is exactly to resolve those dependencies, that project
has to date not been interested in supporting such functionality.
However, this is the use case for many linux systems, and this library
is an initial attempt to get the two approaches to not step on each
other.

### Example usage: ###

    Aeolus::Ext::BundlerExt.system_require(File.expand_path('../../Gemfile.in', __FILE__),:default, Rails.env)

You may also want to wrap your call in some kind of check, to allow
non-platform users (ie, mac, or any developer not installing as a
sysadmin) to still use bundler if they want to.  One example would be
to simply change the name of the Gemfile for rpm setups, something
like:

    mv Gemfile Gemfile.in

Then, just look for a Gemfile, otherwise, load deps via
Gemfile.in/BundlerExt.

Note there is a reason for the 2 files names (for now at least) -
Some libraries, like Rspec, Cucumber, and Rails, try to be smart and
load up dependencies via Bundler themselves if they see a Gemfile in
the working directory.  In some cases this can be overriden, but not
all, so for now at least, it is safer to just look for a different
file (and this is easily scripted as well) In the linux deployment
case, this is not the desired behavior, we explicitly want to say
'just use what the package manager has installed'.
