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

=head1 EXAMPLE USAGE

 DOCUMENT();

 loadMacros("PGstandard.pl", "PGML.pl", "parserGraphToolPointTool.pl");

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
	TEXT(MODES(
		TeX  => '',
		HTML => "<style>"
			. ".gt-tool-button.gt-point-tool {"
			. " background-image: url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='32px'"
			. " height='32px' viewBox='0 0 32 32' version='1.1' %3E%3Cg%3E"
			. " %3Ccircle cx='16' cy='16' fill='%230000ff' stroke-width='0.79351956' r='2.5' /%3E%3C/g%3E%3C/svg%3E\");"
			. "}"
			. "</style>"
	));
}

loadMacros("parserGraphTool.pl");

parser::GraphTool->addGraphObjects(point => {
	js => <<END_OBJECT,
{
	preInit: function(gt, x, y, color) {
		return gt.board.create('point', [x, y], {
			size: 2, snapToGrid: true, snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false,
			strokeColor: color ? color : gt.underConstructionColor, fixed: gt.isStatic,
			highlightStrokeColor: gt.underConstructionColor, highlightFillColor: gt.pointHighlightColor
		});
	},
	postInit: function(gt) {
		if (!gt.isStatic) {
			this.on('down', function() { gt.board.containerObj.style.cursor = 'none'; });
			this.on('up', function() { gt.board.containerObj.style.cursor = 'auto'; });
			this.on('drag', gt.updateText);
		}
	},
	blur: function(gt) {
		this.baseObj.setAttribute({ highlight: false, strokeColor: gt.curveColor, strokeWidth: 2 });
	},
	focus: function(gt) {
		this.baseObj.setAttribute({ highlight: true, strokeColor: gt.focusCurveColor, strokeWidth: 3 });
	},
	stringify: function(gt) {
		return [
			"(" + gt.snapRound(this.baseObj.X(), gt.snapSizeX) + "," +
			gt.snapRound(this.baseObj.Y(), gt.snapSizeY) + ")"
		].join(",");
	},
	updateTextCoords: function(gt, coords) {
		if (this.baseObj.hasPoint(coords.scrCoords[1], coords.scrCoords[2]))
			gt.setTextCoords(this.baseObj.X(), this.baseObj.Y());
	},
	restore: function(gt, string) {
		var pointData;
		var points = [];
		while (pointData = gt.pointRegexp.exec(string))
		{ points.push(pointData.slice(1, 3)); }
		if (points.length < 1) return false;
		return new gt.graphObjectTypes.point(parseFloat(points[0][0]), parseFloat(points[0][1]), gt.curveColor);
	}
}
END_OBJECT
	tikz => {
		code => sub {
			my $self = shift;
			my ($x, $y) = @{$_->{data}[1]{data}};
			my $point = "($x,$y)";
			return ("\\draw[line width=4pt,blue,fill=red] $point circle[radius=5pt];", [
					$point,
					sub { return ($_[0] - $x)**2 + ($_[1] - $y)**2; }
				]);
		}
	}
});

parser::GraphTool->addTools(PointTool => <<END_TOOL);
{
	iconName: "point",
	tooltip: "Point Tool",
	updateHighlights: function(gt, coords) {
		if (typeof(coords) === 'undefined') return false;
		if (!('hl_point' in this.hlObjs)) {
			this.hlObjs.hl_point = gt.board.create('point', [coords.usrCoords[1], coords.usrCoords[2]], {
				size: 2, color: gt.underConstructionColor, fixed: true, snapToGrid: true,
				snapSizeX: gt.snapSizeX, snapSizeY: gt.snapSizeY, withLabel: false
			});
		}
		else
			this.hlObjs.hl_point.setPosition(JXG.COORDS_BY_USER, [coords.usrCoords[1], coords.usrCoords[2]]);

		gt.setTextCoords(coords.usrCoords[1], coords.usrCoords[2]);
		gt.board.update();
		return true;
	},
	deactivate: function(gt) {
		gt.board.off('up');
		gt.board.containerObj.style.cursor = 'auto';
	},
	activate: function(gt) {
		gt.board.containerObj.style.cursor = 'none';
		var this_tool = this;
		gt.board.on('up', function(e) {
			var coords = gt.getMouseCoords(e);

			// Don't allow the point to be created off the board
			if (!gt.board.hasPoint(coords.usrCoords[1], coords.usrCoords[2])) return;
			gt.board.off('up');

			gt.selectedObj = new gt.graphObjectTypes.point(coords.usrCoords[1], coords.usrCoords[2]);
			gt.graphedObjs.push(gt.selectedObj);

			this_tool.finish();
		});
	}
}
END_TOOL

1;
