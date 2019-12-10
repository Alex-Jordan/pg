################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
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

F<parserScore.pl>

=head1 DESCRIPTION

This file implements a Score Math Object class, essentially a Real between 0 and 1.
Its checker returns whatever the answer blank had, assuming that is a real in [0,1].
The idea is that some javascript applet would insert a number like 0 or 1 into a hidden
answer blank, and the student hits submit and gets whatever score was inserted.

Simply make like:
$score = Score();

=cut


loadMacros("MathObjects.pl");

sub _parserScore_init {
  main::PG_restricted_eval('sub Score {value::Score->new(@_)}');
}

package value::Score;
our @ISA = ('Value::Real');

#
#  A context for score objects
#
my $context = Parser::Context->getCopy('Numeric');
$context->{name} = "Score";
$context->{value}{Real} = 'value::Score';       # real numbers create Score objects
$context->variables->clear();                   # no formulas in this context
$context->operators->undefine(',');             # lists not allowed, either

$context->{cmpDefaults}{Score} = {
  checker => sub {
    my ($correct, $student, $ansHash) = @_;
    my $score = $student->value;
    Value::Error('Invalid score')
      unless $score >= 0 && $score <= 1;
    return $score;
  }
};

sub new {
  my $self = shift;
  my $score = $self->SUPER::new($context, 1);
  $score->{isReal} = $score->{isValue} = $score->{isScore} = 1;
  return $score;
}

#
#  Override the class name to get better error messages
#
sub cmp_class {"a Score Value"}

1;
