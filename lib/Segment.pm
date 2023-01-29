=head1 NAME
Segment/Line
=head1 DESCRIPTION
Segment, Line or vector representation as a pair of Point (p1, p2) or Vertex
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

sub isValid($self){
    return $self->directsOnShore();
}

# whether the segment is directed towards the polygon (returns true), false otherwise
# preconditions: the starting point is a Vertex
sub directsOnShore($self){
    my $v=$self->getP1();
    my $angle=$self->getAngle();
    my $prevAngle=$v->getPreviousEdgeAngle();
    my $nextAngle=$v->getNextEdgeAngle();
    if ( ( ($prevAngle <= $angle) && ($angle <= $nextAngle) ) || ( ($nextAngle <= $angle) && ($angle <= $prevAngle) ) ){
        return 1;
    }
    return 0;
}

# compute the intersection with another line
# returns intersection as a Point or undef is lines are parallel
sub computeLineIntersection($self,$s2){
    # segment 1: y=(y2-y1)/(x2-x1)*(x-x1)+y1
    # segment 2: y=(y4-y3)/(x4-x3)*(x-x3)+y3
    # intersection: 2 equations - 2 unknows
    # general case:
    # x=x1*(y2-y1)/(x2-x1)-x3*(y4-y3)/(x4-x3)+y3-y1
    # y=
    # special cases: 
    # x=x2=x1 and x3!=x4 y=(y4-y3)/(x4-x3)*(x1-x3)+y3
    # x=x3=x4 and x2!=x1 and y=(y2-y1)/(x2-x1)*(x3-x1)+y1
    # x=x3=x4=x2=x1 and any y=> overlapping segments
    # x=x2=x1 and x3=x4 and x3!=x1 => undef (parallel disctinct lines)
    my $s1=$self;
    # alias for readability
    my $x1=$s1->getP1()->{x};
    my $y1=$s1->getP1()->{y};
    my $x2=$s1->getP2()->{x};
    my $y2=$s1->getP2()->{y};

    my $x3=$s2->getP1()->{x};
    my $y3=$s2->getP1()->{y};
    my $x4=$s2->getP2()->{x};
    my $y4=$s2->getP2()->{y};

    # searched intersection point
    my $x;
    my $y;
    # compute denominator first to identify formula
    my $d1=$x2-$x1;
    my $d2=$x4-$x3;
    
    if ( ($d1==0) && ($d2==0) ){ 
        if ($x1==$x3){
            # overlapping segment (for candidate validation, it's fine)
            $x=$x1;
            $y=undef; # good rep?
        }else{
            return undef; # distinct parallel
        }
    }elsif ($d1==0){ #x=x1=x2 and x3!=x4
        $x=$x1;
        $y=($y4-$y3)/($x4-$x3)*($x1-$x3)+$y3;
    }elsif ($d2==0){ #x=x3=x4 and x2!=x1
        $x=$x3;
        $y=($y2-$y1)/($x2-$x1)*($x3-$x1)+$y1;
    }else{
        $x=$s1->getP1()->{x}*($s1->getP2()->{y}-$s1->getP1()->{y});
        my $d1=($s1->getP2()->{x}-$s1->getP1()->{x});
        $x/=$d1;
        $x-=$s2->getP1()->{x}*($s2->getP2()->{y}-$s2->getP1()->{y});

        $x+=$s2->getP1()->{y}-$s1->getP1()->{y};
        # check whether denominator is zero
        my $d=($s1->getP2()->{y}-$s1->getP1()->{y})/($s1->getP2()->{x}-$s1->getP1()->{x})-($s2->getP2()->{y}-$s2->getP1()->{y})/($s2->getP2()->{x}-$s2->getP1()->{x});
        if ($d==0){ # TBC < 10-6
            return undef;}
        $x/=$d;
        # y=(y3-y1)/(x2-x1)*(x-x1)+y1
        $y=($s1->getP2()->{y}-$s1->getP1()->{y})/($s1->getP2()->{x}-$s1->getP1()->{x})*($x-$s1->getP1()->{x})+$s1->getP1()->{y}; 
    }
    return Point->new(x=>$x,y=>$y);
}

# whether Segment intersects with $s2 Segment Interior i.e. at a Point different than the $s2 Segment ends
# returns true or false
# Note: Be careful of $s2 Interior (you should not swap $self and $s2)
sub intersectsSegmentInterior($self,$s2){
    my $inter=$self->computeLineIntersection($s2);
    if (!$inter){
        return 0;
    }
    # check whether line intersection is touching both Segments
    # aliases for readability
    my $x1=$self->getP1()->{x};
    my $y1=$self->getP1()->{y};
    my $x2=$self->getP2()->{x};
    my $y2=$self->getP2()->{y};

    my $x3=$s2->getP1()->{x};
    my $y3=$s2->getP1()->{y};
    my $x4=$s2->getP2()->{x};
    my $y4=$s2->getP2()->{y};

    # any coordinates of the $s2 segment allow to validate $s2 interior segment intersection
    if ( ($x3<$inter->{x} && $inter->{x}<$x4) || ($x4<$inter->{x} && $inter->{x}<$x4) ){
        return 1;
    }
    if ( ($y3<$inter->{y} && $inter->{y}<$y4) || ($y4<$inter->{y} && $inter->{y}<$y3) ){
        return 1;
    }
    return 0;
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