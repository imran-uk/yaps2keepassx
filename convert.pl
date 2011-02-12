#!/usr/bin/perl

use strict;
use IO::File;
use Data::Dumper;

## FORMAT
## Field 0 - unused?
## Field 1 - name
## Field 2 - location - eg. "forum", <website url>
## Field 3 - username
## Field 4 - password
## Field 5 - comment - may contain ',', may contain nuts, may be multiline, must NOT begin with #^,#
my $input_file = 'yaps.txt';
my $output_file = 'yaps.xml';
my $dest_header = <<XML;
<!DOCTYPE KEEPASSX_DATABASE>
<database>
XML
my $dest_footer = <<XML;
</database>
XML
my $source_hash = {};
my $count = 0;
my $DEBUG = 0;
my $name = 'none';
my $start_record = '#,';

## get them all into a hash, then sort by name
my $source = IO::File->new;
$source->open($input_file);
my $dest = IO::File->new;
$dest->open(">$output_file");

## XXX multiline comments field is not handled properly

while(<$source>)
{
	chomp;

	if(/^\#\,/)
	{
		## Start of new record
		my @line = split(',', $_, 6);

		if(exists $source_hash->{$line[1]})
		{
			$name = $line[1] . "-$count";
		}
		else
		{
			$name = $line[1];
		}

		$source_hash->{$name} = {
			name 			=> 	$line[1],
			location 	=> 	$line[2],
			username	=> 	$line[3],
			password	=> 	$line[4],
			comment	=> 	"$line[5]\n"
		};
	}
	else
	{
		## Continuation of previous record comments
		$source_hash->{$name}->{'comment'} .= "$_\n";
	}
}

if($DEBUG)
{
	foreach my $name (sort keys %$source_hash)
	{
		## remove the trailing newline from the comment
		my $comment = $source_hash->{$name}->{'comment'};
		chomp($comment);
		print STDERR Dumper($name, $comment);
	}
}

## Convert to KeePassX XML
$dest->print($dest_header);

foreach my $name (sort keys %$source_hash)
{
	## remove the trailing newline from the comment
	my $comment = $source_hash->{$name}->{'comment'};
	chomp($comment);
	my $title = $source_hash->{$name}->{'location'};

	if($title =~ /^\s*$/)
	{
		$title = $source_hash->{$name}->{'name'};
	}

	my $group = <<XML;
<group>
	<title>$name</title>
	<entry>
		<title>$title</title>
		<username>@{[ $source_hash->{$name}->{'username'} ]}</username>
		<password>@{[ $source_hash->{$name}->{'password'} ]}</password>
		<comment>$comment</comment>
  </entry>
</group>
XML
	$dest->print($group);
}

$dest->print($dest_footer);
