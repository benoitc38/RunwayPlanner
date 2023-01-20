=pod
Represents a point set and therefore maybe used to represent a Polygon
When representing a Polygon, point order is counter clockwise by convention
Some methods are only relevant for Polygon so you may want to derive Polygon from Points at some point;-)
=cut
package Points;
use Moose;
#use Point;

has 'points' => (is=>'rw', isa=>'ArrayRef[Point]');

sub toString{
    my $self=shift;
    my $st="";
    $st=join(',',map($_.toString(),$self->{points}));
    return $st;
}

1
