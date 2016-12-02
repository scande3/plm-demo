# README

## Concepts

### Hierarchy

#### Background

As I tried out PatientsLikeMe, I noticed something a bit unusual. For example, 930 users suffer from the condition of
"heart attack" (Myocardial Infarction). Then we go one level broader and it seems like 46 people suffer from 
"Myocardial Ischemia". . . but what happened to those 930 other users who suffer from a specific version of that
condition? Going one level deeper than the initial heart attack shows that the 39 that specified the type of heart attach as
"Non-ST Elevated Myocardial Infarction" are lacking from the "heart attack" report.

These reports are the following (from most specific to more general):
1. [https://www.patientslikeme.com/conditions/522-non-st-elevation-myocardial-infarction/overview](https://www.patientslikeme.com/conditions/522-non-st-elevation-myocardial-infarction/overview)

2. [https://www.patientslikeme.com/conditions/281-heart-attack/overview](https://www.patientslikeme.com/conditions/281-heart-attack/overview)

3. [https://www.patientslikeme.com/conditions/1495-myocardial-ischemia/overview](https://www.patientslikeme.com/conditions/1495-myocardial-ischemia/overview)


While the knowledge as to the diagnosis level people reported is important, I'd say that leaving out more specific reports
of broader concepts is overall inaccurate. Trying out other means, it does seem the site is completely unaware of medical
hierarchy. Furthermore, it even seems to have trouble with alternative labels at times, as doing searches for the scientific
term for "heart attack" of "Myocardial Infarction" will give different reasults in the general search.

#### My Implementation

I've done a rough implementation of a system that is aware of the medical hiearchy provided by MeSH. It is solely a proof of
concept as to how it might be done.

### Condition Entry

#### Background

I actually knew from time at Emory University School of Medicine that "Myocardial Infarction" was the correct term for
what is commonly called a "heart attack". This was the first term I tried to put into the system. . . and the system did
provide me with "heart attack" as the first result. In this case, I knew that was a synonym for what I was typing, but 
there was no indication that it was thus in the simple type-ahead. Furthermore, there was a more specific and a more general 
concept of this in the list that could confuse things as to what is best to select without context. The optimization of the
autocomplete is amazing stuff (impressed that I can't do much to fool it) but unsure if it is the best interface.

#### My Implementation

Several of us in the library IT community have started to move towards the concept of a "Metadata Enrichment Interface".
Essentially that for complex datasets, type-aheads are just too limiting. In this case, the interface I expose gives one
that broader and narrower context along with the alternative labels. Beyond the clarity on what a term means, it can lead
a user to make more specific selections as they see what narrower options of their condition are available.

Unfortunately, beyond being a bit rough, the interface is designed for use by staff over the general public. It
would take a redesign to make it less imposing and more clear on its operation. Just a proof of concept of the idea.

### Geographic Parsing

#### My Implementation

Just as it was the easiest to show off, quick usage of a ruby gem I had developed to parse strings for geographic
data and then display where people are on a map in the search results.


## Try It Out

<server URL here>

## Vagrant Instructions

Coming a couple of hours.

## Installation Instructions

Coming a couple of hours.

## Gem References

1. [https://github.com/ActiveTriples/linked-data-fragments](Linked Data Fragments)
   * The idea with this codebase is that Linked Data requires a caching layer like Marmotta, Blazegraph, Apache Stanbol, etc.
     While Blazegraph is emerging as a winner, each institution picks their own stack, and a lack of standard interface has made
     code sharing difficult. Additionally, by abstracting out this layer, one can switch the technology stack being used with
     far less effort.
     
   * Sadly, development has been slow on this code. While resolving subjects in a triple are easy, getting suggestions isn't
     supported yet so I did often have to hit Blazegraph's SPARQL yet. 
     
   * Sample commit: [https://github.com/ActiveTriples/linked-data-fragments/pull/18](https://github.com/ActiveTriples/linked-data-fragments/pull/18)

2. [https://github.com/projecthydra-labs/geomash](Geomash)
     * Written initially to support the geographic functionality of Digital Commonwealth, this codebase is on its last legs.
       For the past year, it has just been "keep it working" mode as I'd like to redo it. Especially some version that is hosted
       and can learn from the data hitting it rather than it just being a distributed gem.
       
     * Sample commit: All except for one albeit the most recent ones are just quick hacks to hotfix more systemic issues.
       
2. [https://github.com/boston-library/mei](Mei) (short for Metadata Enrichment Interface)
     * Designed to be the first selling point of Linked Data Fragments, it is to replace autocomplete for more complex fields.
       
     * The initial version mostly worked with the Library of Congress Linked Data endpoint. I just hacked out some 
        of the "library world" dependencies like active-fedora and added in MeSH for this. Very much experimentation 
        and horribly coded at the moment.
 
## Final Mentions

Feel free to use any ideas or concepts from this. I don't reserve any right on this code.