Micro Inferer
    by VisFleet Labs
    http://labs.visfleet.com

== DESCRIPTION:
  
A micro inference engine.

=== Example

= Declare your rules
inferer = Micro::Inferer.new
inferer.when(:wet).and(:cold).it_is(:raining)
inferer.when(:raining).and(:windy).or(:july).it_is(:winter)

= State the facts
inferer.it_is(:wet)
inferer.it_is(:windy)

= Infer stuff
inferer.infer
> :winter

=== Reasons to use an inference engine

- Performance will be better when:
  - You have more rules that unique conditions
  - You facts change piece meal
  
- The logic is complex.

- Things become true over time. Also better performance as bits that are true are already computed.

- Declarative rules can be tidier


=== Performance

Performance is O(FR(f)) where F is the number facts that changed, and R(f) is the number of rules that contain this fact. 
Compared to a IF..THEN...ELSE rule whose performance is O(RC) where R is the number of rules.

== INSTALL:

sudo gem install micro_inferer

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
