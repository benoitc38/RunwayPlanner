=head1 NAME
Segment/Line
=head1 DESCRIPTION
Segment, Line or vector representation as a pair of Point (p1, p2)
The segment or Line are not oriented but by convention, the first point is named p1, the second one p2
=cut

package Segment;
use Modern::Perl;
use experimental 'signatures';
use FindBin::libs;
use Points;
use Moose;

use Math::Trig;
#use Math::Trig ':pi';

extends 'Points';

# cache for length
has length => (
                 is=>'rw',
                 isa=>'Maybe[Num]',
                 default=>sub{undef}
              );

# starting point 
sub getP1{
    my $self=shift;
    return ($self->all_points())[0];
}

# ending point
sub getP2{
    my $self=shift;
    return ($self->all_points())[1];
}

# compute or get from cache segment length as sqrt((x2-x1)^2+(y2-y1)^2)
sub getLength{
    my $self=shift;
    if (!$self->length){
        $self->length(sqrt(($self->getP2()->{x}-$self->getP1()->{x})**2+($self->getP2()->{y}-$self->getP1()->{y})**2));
    }
    return $self->length;
}

# compare length with another segment
# input: $segment2
# returns 1 if longer, 0 if equals, and -1 if shorter than segment 2
sub isLongerThan($self, $segment2){
    return ($self->getLength() <=> $segment2->getLength());
}

# returns the Segment angle measured from the x axis between -PI and PI
# unit: degrees for easier use
# P1->P2 : arctan(y2-y1)/(x2-x1) 
sub getAngle($self){
    my $x1=$self->getP1()->{x};
    my $y1=$self->getP1()->{y};
    my $x2=$self->getP2()->{x};
    my $y2=$self->getP2()->{y};
    return atan2($y2-$y1,$x2-$x1)/pi*180;
}

# compute the intersection with another line
# returns intersection as a Point or undef is lines are parallel
sub computeLineIntersection{
    my $self=shift;
    my $s2=shift;
    # segment 1: y=(y2-y1)/(x2-x1)*(x-x1)+y1
    # segment 2: y=(y4-y3)/(x4-x3)*(x-x3)+y3
    # intersection: 2 equations - 2 unknows
    # x=x1*(y2-y1)/(x2-x1)-x3*(y4-y3)/(x4-x3)+y3-y1
    # y=
    my $s1=$self;
    my $x=$s1->getP1()->{x}*($s1->getP2()->{y}-$s1->getP1()->{y});
    my $d=($s1->getP2()->{x}-$s1->getP1()->{x});
    if (!$d){
        print("Vertical segment 1 not yet supported");
        return undef;
    }
    $x/=$d;
      $x-=$s2->getP1()->{x}*($s2->getP2()->{y}-$s2->getP1()->{y});
      $d=($s2->getP2()->{x}-$s2->getP1()->{x});
      if (!$d){
        print("Vertical segment 2 not yet supported");
        return undef;
      }
      $x+=$s2->getP1()->{y}-$s1->getP1()->{y};
      # check whether denominator is zero
      $d=($s1->getP2()->{y}-$s1->getP1()->{y})/($s1->getP2()->{x}-$s1->getP1()->{x})-($s2->getP2()->{y}-$s2->getP1()->{y})/($s2->getP2()->{x}-$s2->getP1()->{x});
    if ($d==0){ # TBC < 10-6
        return undef;}
    $x/=$d;
    my $y=($s1->getP2()->{y}-$s1->getP1()->{y})/($s1->getP2()->{x}-$s1->getP1()->{x})*($x-$s1->getP1()->{x})+$s1->getP1()->{y};
    return Point->new(x=>$x,y=>$y);
}

sub computeSegmentIntersection{
    my $self=shift;
}

# whether the segment is a valid airport proposal
# candidate segments partly off shore are invalid
sub isValidAirport{
    return 1; # TBC
}

# segment is displayed in green
# <line x1="0" y1="80" x2="100" y2="20" stroke="green">
sub toSVGHTMLTagString($self){
    return "<line ${\$self->getP1()->toSVGSegmentString(1)} ${\$self->getP2()->toSVGSegmentString(2)} fill=\"none\" stroke=\"green\" />";
}

sub toString{
    my $self=shift;
    my $st="";
    $st.="\np1:".$self->getP1()->toString();
    $st.="p2:".$self->getP2()->toString();
    $st.="length:".$self->getLength();
    return $st;
}

no Moose;
__PACKAGE__->meta->make_immutable;