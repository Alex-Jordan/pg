################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2021 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

parserGraphToolPointTool.pl - Adds a point graphing tool to the GraphTool in
L<parserGraphTool.pl>.

=head1 DESCRIPTION

This adds a point graph object and point graphing tool to the GraphTool.
See the L<parserGraphTool.pl> documentation for the general GraphTool usage.

This macro adds a Point graph object and a Point Tool used to graph that object.
The syntax of this object to pass to the GraphTool constructor is the name
"point" followed by the coordinates for the point.  For example:

    "{point,(3,5)}"

Note that all of the usual graph objects and graph tools that are documented in
L<parserGraphTool.pl> are also available for use with this macro as that macro
is loaded by this one.

=head1 EXAMPLE USAGE

 DOCUMENT();

 loadMacros("PGstandard.pl", "PGML.pl", "GraphToolPoint.pl");

 TEXT(beginproblem());

 $x = random(-5, 5);
 $y = random(-5, 5);

 $gt = GraphTool("{point, ($x, $y)}")->with(
     availableTools => [ "PointTool" ],
     bBox => [-11, 11, 11, -11],
     showCoordinateHints => 0,
     cmpOptions => {
         list_checker => sub {
             my ($correct, $student, $ans, $value) = @_;

             my $score = 0;
             my @errors;
             my $count = 1;

             # Get the correct point.
             my ($cx, $cy) = $correct->[0]->extract(1)->value;

             for (@$student) {
                 my $nth = Value::List->NameForNumber($count++);

                 $score += 1, next
                 if ($_->extract(1) eq $correct->[0]->extract(1) &&
                     $_->extract(2) eq $correct->[0]->extract(2));

                 push(@errors, "The $nth object graphed is not a point."),
                 next if ($_->extract(1) ne $correct->[0]->extract(1));

                 push(@errors, "The $nth object graphed is incorrect.");
             }

             return ($score, @errors);
         }
     }
 );

 BEGIN_PGML
 Graph the point [`([$x], [$y])`].

 [_]{$gt}
 END_PGML

 ENDDOCUMENT();

=cut

sub _parserGraphToolPointTool_init {
	ADD_JS_FILE('js/apps/GraphTool/pointtool.js', 0, { defer => undef });
}

loadMacros('parserGraphTool.pl');

parser::GraphTool->addGraphObjects(point => {
	js => 'graphTool.pointTool.graphObject',
	tikz => {
		code => sub {
			my $self = shift;
			my ($x, $y) = @{$_->{data}[1]{data}};
			my $point = "($x,$y)";
			return ("\\draw[line width=4pt,blue,fill=red] $point circle[radius=5pt];", [
					$point,
					sub { return ($_[0] - $x) ** 2 + ($_[1] - $y) ** 2; }
				]);
		}
	}
});

parser::GraphTool->addTools(PointTool => 'graphTool.pointTool.graphTool');

1;
