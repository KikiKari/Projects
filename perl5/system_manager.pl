#!/usr/bin/perl
# system_manager.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/system_manager.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/system_manager.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

=head1 NAME

system_manager.pl - System management abstraction for Ubuntu and CentOS 8

=head1 SYNOPSIS

system_manager.pl [options]

 Options:
   --os          Operating system (ubuntu|centos)
   --action      Action to perform
   --package     Package name
   --service     Service name
   --port        Port number
   --proto       Protocol (default: tcp)
   --username    Username
   --generate    Generate script instead of execute
   --help        Show this help message

=cut

# Define SystemCommand as a hash reference structure
my %COMMANDS = (
    "install" => {
        ubuntu => "apt-get install -y {package}",
        centos => "dnf install -y {package}",
        description => "Install a package"
    },
    "remove" => {
        ubuntu => "apt-get remove -y {package}",
        centos => "dnf remove -y {package}",
        description => "Remove a package"
    },
    "update" => {
        ubuntu => "apt-get update && apt-get upgrade -y",
        centos => "dnf update -y",
        description => "Update all packages"
    },
    "search" => {
        ubuntu => "apt-cache search {package}",
        centos => "dnf search {package}",
        description => "Search for package"
    },
    "service_start" => {
        ubuntu => "systemctl start {service}",
        centos => "systemctl start {service}",
        description => "Start a service"
    },
    "service_stop" => {
        ubuntu => "systemctl stop {service}",
        centos => "systemctl stop {service}",
        description => "Stop a service"
    },
    "service_enable" => {
        ubuntu => "systemctl enable {service}",
        centos => "systemctl enable {service}",
        description => "Enable service at boot"
    },
    "service_status" => {
        ubuntu => "systemctl status {service}",
        centos => "systemctl status {service}",
        description => "Check service status"
    },
    "firewall_allow" => {
        ubuntu => "ufw allow {port}/{proto}",
        centos => "firewall-cmd --add-port={port}/{proto} --permanent && firewall-cmd --reload",
        description => "Open firewall port"
    },
    "firewall_status" => {
        ubuntu => "ufw status",
        centos => "firewall-cmd --list-all",
        description => "Check firewall status"
    },
    "add_user" => {
        ubuntu => "adduser --disabled-password --gecos '' {username}",
        centos => "adduser {username}",
        description => "Add system user"
    },
    "add_to_sudo" => {
        ubuntu => "usermod -aG sudo {username}",
        centos => "usermod -aG wheel {username}",
        description => "Add user to sudoers"
    },
);

# Package name mappings (same software, different package names)
my %PACKAGE_MAP = (
    "apache" => { ubuntu => "apache2", centos => "httpd" },
    "mysql" => { ubuntu => "mysql-server", centos => "mysql-server" },
    "php" => { ubuntu => "php", centos => "php" },
    "nodejs" => { ubuntu => "nodejs", centos => "nodejs" },
    "nginx" => { ubuntu => "nginx", centos => "nginx" },
);

# SystemManager class implemented as a Perl package
{
    package SystemManager;

    sub new {
        my ($class, $os_type) = @_;
        my $self = {
            os => lc($os_type)
        };
        bless $self, $class;
        
        if ($self->{os} ne "ubuntu" && $self->{os} ne "centos") {
            die "Unsupported OS: $os_type\n";
        }
        
        return $self;
    }

    sub get_command {
        my ($self, $action, %kwargs) = @_;
        my $cmd_template = $COMMANDS{$action};
        
        if (!$cmd_template) {
            die "Unknown action: $action\n";
        }
        
        # Get OS-specific command
        my $cmd;
        if ($self->{os} eq "ubuntu") {
            $cmd = $cmd_template->{ubuntu};
        } else {
            $cmd = $cmd_template->{centos};
        }
        
        # Format with arguments
        for my $key (keys %kwargs) {
            my $value = $kwargs{$key};
            $cmd =~ s/\{$key\}/$value/g;
        }
        
        return $cmd;
    }

    sub get_package_name {
        my ($self, $software) = @_;
        my $mapping = $PACKAGE_MAP{lc($software)} || {};
        return $mapping->{$self->{os}} || $software;
    }

    sub detect_os {
        my ($self) = @_;
        if (-f "/etc/os-release") {
            open(my $fh, '<', "/etc/os-release") or return undef;
            my $content = do { local $/; <$fh> };
            close($fh);
            
            $content = lc($content);
            if ($content =~ /ubuntu|debian/) {
                return "ubuntu";
            } elsif ($content =~ /centos|rhel|fedora/) {
                return "centos";
            }
        }
        return undef;
    }

    sub generate_script {
        my ($self, $actions) = @_;
        my @lines = ("#!/bin/bash", "set -e", "");
        
        for my $action (@$actions) {
            my %action_copy = %$action;
            my $cmd_name = delete $action_copy{action};
            push @lines, "# " . $COMMANDS{$cmd_name}->{description};
            push @lines, $self->get_command($cmd_name, %action_copy);
            push @lines, "";
        }
        
        return join("\n", @lines);
    }
}

# Main execution
sub main {
    my %args = (
        os => '',
        action => '',
        package => undef,
        service => undef,
        port => undef,
        proto => 'tcp',
        username => undef,
        generate => 0,
        help => 0
    );

    GetOptions(
        'os=s' => \$args{os},
        'action=s' => \$args{action},
        'package=s' => \$args{package},
        'service=s' => \$args{service},
        'port=s' => \$args{port},
        'proto=s' => \$args{proto},
        'username=s' => \$args{username},
        'generate' => \$args{generate},
        'help|?' => \$args{help}
    ) or pod2usage(2);

    pod2usage(1) if $args{help};
    pod2usage(2) unless $args{os} && $args{action};

    my $manager = SystemManager->new($args{os});
    
    # Build kwargs from args
    my %kwargs = ();
    if ($args{package}) {
        $kwargs{package} = $manager->get_package_name($args{package});
    }
    if ($args{service}) {
        $kwargs{service} = $args{service};
    }
    if ($args{port}) {
        $kwargs{port} = $args{port};
        $kwargs{proto} = $args{proto};
    }
    if ($args{username}) {
        $kwargs{username} = $args{username};
    }
    
    my $cmd = $manager->get_command($args{action}, %kwargs);
    
    if ($args{generate}) {
        print "$cmd\n";
    } else {
        print "Executing: $cmd\n";
        # system($cmd);  # Uncomment to actually execute
    }
}

main() unless caller;

1;
