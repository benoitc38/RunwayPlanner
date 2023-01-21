=pod
Represents a point set and therefore maybe used to represent a Polygon
When representing a Polygon, point order is counter clockwise by convention
Some methods are only relevant for Polygon so you may want to derive Polygon from Points at some point;-)
=cut
package Points;
use Point;
use Moose;


has 'points' => (
                    is=>'rw', 
                    isa=>'ArrayRef[Point]',
                    traits  => ['Array'],
                    handles =>{
                       all_points => 'elements',
                       count_points  => 'count' 
                    }
                );

# create an instance from a multi line string with first line containing line#
# following lines containing the point coordinates
# static class builder method
sub CreateFromString{
    my $cls=shift;
    my $st=shift;
    my @lines=split("\n",$st);
    my $line_count=@lines;
    # validation: check first line has the right count
    if (!$line_count){
        print("Empty input file!"); # TBI error log
        return undef;
    }
    my $first_line_count=shift(@lines);
    if ($first_line_count!=$line_count-1){
        print("Inconsistent first line $first_line_count! Expecting ($line_count-1) instead)");
        return undef
    }
    my @points=map(Point->CreateFromString($_), @lines);
    return Points->new(points=>\@points);
}

sub toString{
    my $self=shift;
    my $st="";
    #my $count=$self->count_points;
    $st.='['.join(',',map($_->toString(), $self->all_points())).']';
    return $st;
}

no Moose;
1
