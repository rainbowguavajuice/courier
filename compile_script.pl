#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use Data::Dumper;

my $SCRIPT_PATH = 'script/';
my $SCRIPT_EXTENSION = '\.script';

my $SCRIPT_PREFIX = 'p_';

my $WIDGET_PREFIX = 'w_';

my $QR_SCRIPT_PREFIX = qr/$SCRIPT_PREFIX/;
my $QR_SCRIPT_NAME = qr/[a-z]+(?:_[a-z]+)*/;
my $QR_SCRIPT_FULL_NAME = qr/[a-z]+(?:__?[a-z]+)*/;

my $QR_SCRIPT_PATH = qr/$SCRIPT_PATH/;
my $QR_SCRIPT_EXTENSION = qr/$SCRIPT_EXTENSION/;

my $QR_WIDGET_DELIM_L = qr/<</;
my $QR_WIDGET_DELIM_M = qr/\|/;
my $QR_WIDGET_DELIM_R = qr/>>/;

my $QR_CODE_DELIM_L = qr/\{\{/;
my $QR_CODE_DELIM_R = qr/\}\}/;


my @script_files = ();

# convert full path of script file to function name
sub path_to_label {
    my ($f) = @_;
    # the checking on the script name is done by the caller; here it's
    # just matched by the group (.*).
    $f =~ s/^${QR_SCRIPT_PATH}(.*)${QR_SCRIPT_EXTENSION}$/$1/;
    $f =~ s/\//__/g;
    $SCRIPT_PREFIX . $f;
}

sub name_to_index {
    my ($s) = @_;
    uc ($SCRIPT_PREFIX . $s);
}
sub label_to_index {
    my ($s) = @_;
    uc $s;
}

sub process_widget_element {
    my ($raw, $code) = @_;

    # there is a shorthand here: the contents of widget of type
    # <<...>> always gets evaluated as code, because there would be no
    # point putting plain text in it.
    if ($raw =~ /^${QR_CODE_DELIM_L}(.*)${QR_CODE_DELIM_R}$/s) {
	$raw = $1;
	$code = 1;
    }
    return '(game) => ' . ($code ? $raw : "\"$raw\"");
}

# depending on the kind of widget, generate the handlers and add
# placeholders to the HTML string.
my $process_widget_index = 0;
sub process_widget {
    my ($raw, $widget_elements, $widget_handlers) = @_;
    my $widget_index = $process_widget_index;

    # there are three kinds of widgets, identified in this order:
    #
    # <<...|destination>> if (destination) has the format of a pasage
    #                     name, this is shorthand for a link that
    #                     sends the player to another passage.
    #
    # <<...|{{code}}>> is a link that execudes {{code}} as javascript
    #                  on click . the curly brackets make this clear,
    #                  because the | character can show up in
    #                  javascript, but everything that doesn't match
    #                  these first two cases defaults to...
    #
    # <<...>> ...only displays its contents.
    #

    my ($w_h, $w_e);
    if ($raw =~ /^(.*)${QR_WIDGET_DELIM_M}(${QR_SCRIPT_FULL_NAME})$/s) {
	
	$w_h = '(game) => ((e) => go_to(game, ' . name_to_index $2 . '))';
	$w_e = process_widget_element $1, 0;

    } elsif ($raw =~ /^(.*)${QR_WIDGET_DELIM_M}${QR_CODE_DELIM_L}(.*)${QR_CODE_DELIM_R}$/s) {

	$w_h = '(game) => ((e) => {' . $2 . '})';
	$w_e = process_widget_element $1, 0;

    } else {

	$w_h = 'null';
	$w_e = process_widget_element $1, 1;

    }
    
    push @$widget_elements, $w_e;
    push @$widget_handlers, $w_h;
    
    ++$process_widget_index;
    return "<span id=\"$WIDGET_PREFIX$widget_index\"></span>";
}

# read from a script file and generate the corresponding js function.
sub process_file {
    my ($fh, $index, $path, $label) = @_;
    
    # slurp entire contents of file
    my $fhr;
    my $raw = do {
	local $/ = undef;
	open $fhr, '<', $path or die "failed to read script file";
	<$fhr>;
    };
    close $fhr;

    # the bulk of the work happens inside the s//ge regex, which calls
    # the subroutine that generates some bits of javascript
    $process_widget_index = 0;
    my @widget_elements = ();
    my @widget_handlers = ();

    # replace the widgets recursively, starting from the innermost
    # brackets. it is kind of cursed that this kind of works
    while ($raw =~ s/${QR_WIDGET_DELIM_L}((?:(?!${QR_WIDGET_DELIM_L}).)*?)${QR_WIDGET_DELIM_R}/
process_widget $1, \@widget_elements, \@widget_handlers/sge) {};

    # finally, write to file.
    print $fh "function $label (game, dom_parent) {\n";
    print $fh "let e_list = [\n" . (join ",\n", @widget_elements) . "\n];\n";
    print $fh "let h_list = [\n" . (join ",\n", @widget_handlers) . "\n];\n";
    print $fh "let raw = '$raw\';\n";
    print $fh "render_passage(game, dom_parent, raw, e_list, h_list);\n";
    print $fh "}\n\n";
}

# recursively find all script files and process each of them.
find(
    sub {
	my $f = $File::Find::name;
	# print $f, "\n" if $f =~ /.script$/;
	if ($_ =~ /^${QR_SCRIPT_NAME}${QR_SCRIPT_EXTENSION}$/) {
	    push @script_files, [$f, path_to_label $f];
	    print ($f . ' - ' . (path_to_label $f) . "\n");
	} else {
	    print "rejected script file with invalid name ($f)\n" if -f;
	}
    },
    $SCRIPT_PATH);


open my $fh, '>', 'script.js' or die "failed to create js file";

# define constants for passage indices
for my $i (0 .. $#script_files) {
    my ($path, $label) = @{$script_files[$i]};
    print $fh ('const ' . (label_to_index $label) . ' = ' . $i . "\n");
}
# generate the corresponding functions
for my $i (0..$#script_files) {
    process_file $fh, $i, @{$script_files[$i]};
}
# put all the function names into a list
print $fh "let passage_list = [\n";
print $fh (join ",\n", map { @{$_}[1]; } @script_files);
print $fh "\n];\n";


close $fh;
