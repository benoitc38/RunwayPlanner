=head1
Represents a point within a point set(Polygon or Segment)
=cut
package Vertex;
use Modern::Perl;
use experimental 'signatures';
use Moose;

#BEGIN { extends 'Point' }
extends 'Point';

# container parent is typically a point set such as a Polygon or Segment
has 'container' => (
                    is=>'rw',
                    isa=>'Maybe[Points]',
                    required=>0,
                    default=>sub{undef}
                 );

# index within its container for next/previous methods support
has index => (
                is=>'rw',
                isa=>'Maybe[Int]',
                required=>0,
                default=>sub{undef}
             );

# counter-clockwise is the normal so this method goes clockwise
# returns a Vertex
sub getPrevious($self){
    return $self->container->getVertexByIndex($self->index-1);
}

# this method goes counter-clockwise
# returns a Vertex
sub getNext($self){
    return $self->container->getVertexByIndex(($self->index+1) % $self->container->count_points());
}

# returns previous edge (going clockwise) adjacent to this vertex
sub getPreviousEdge($self){
    return $self->container->getEdgeByIndex($self->index-1);
}

# returns next edge (counter-clockwise) adjacent to this vertex
sub getNextEdge($self){
    return $self->container->getEdgeByIndex($self->index);
}

# returns the absolute angle of the next edge
# input: $edge as a Segment
sub getEdgeAngle($self, $edge){
    # bug direction not taken into account but let's start with that
    return $edge->getAngle();
}

# returns previous edge angle relative to the x-axis
# !! previous edges are counter-clockwise oriented at edge build
# but from current edge it should be oriented in the opposite direction
sub getPreviousEdgeAngle($self){
    my $angle=$self->getEdgeAngle($self->getPreviousEdge());
    $angle=($angle+180)%180; # flip it
    return $angle;
}

# next edge angle relative to the x-axis
sub getNextEdgeAngle($self){
    return $self->getEdgeAngle($self->getNextEdge());
}

override 'toString' => sub($self){
    my $st="";
    $st.="V".super();
=pod
    if (defined($self->container) && exists($self->container->name)){
        $st.=$self-container->name;
    }
=cut
    if (defined($self->index)){
        $st.=$self->index;
    }
  return $st;
};
=pod
sub toString($self){
    return "V".$self->toString();
}
=cut
no Moose;
__PACKAGE__->meta->make_immutable;