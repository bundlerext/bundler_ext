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

### Example usage ###

If you want to load ALL Gemfile groups, use the following statement:

    Aeolus::Ext::BundlerExt.system_require(File.expand_path('../../Gemfile.in', __FILE__), :all)

When you want to load only the default one, use:

    Aeolus::Ext::BundlerExt.system_require(File.expand_path('../../Gemfile.in', __FILE__), :default)

You can provide multiple parameters to the system_require function
of course. Finally, you will be likely requiring default group and
group named as the current Rails environment; use this:
    
    Aeolus::Ext::BundlerExt.system_require(File.expand_path('../../Gemfile.in', __FILE__), :default, Rails.env)

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

### Additional configuration ###

There are special environment variables you can use. You may need to 
insert additional groups to be required, e.g. when developing and you
want to restart the system in development mode once. Use 
BUNDLER_EXT_GROUPS variable (separate with whitespace):

    BUNDLER_EXT_GROUPS="group1 group2 group3" rails server ...

Also, by default bundler_ext raises an error when dependency cannot
be loaded. You can turn off this behavior (e.g. for installers when
you want to do rake db:migrate) with setting BUNDLER_EXT_NOSTRICT:

    BUNDLER_EXT_NOSTRICT=1 rake db:migrate ...

In this mode bundler_ext prints out error messages on the stdout, 
but does not terminate the process.

Some rubygems require HOME environment variable to be set, threfore
not running daemonized. For this purposes there is BUNDLER_EXT_HOME
variable which can be used to set HOME environment variable before
any rubygem gets loaded. The variable is not exported for
subprocesses.
