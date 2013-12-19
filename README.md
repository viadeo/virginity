# Virginity

A pure Ruby vCard parser and vCard builder.

Internally it uses vCard 3.0 but it has modules to read and write from/to vCard 2.1. (With some limitations as a result of the data formats.)

## History

At the end of 2011, Viadeo acquired Soocial. Soocial was an address book syncing service and an office full 
of Rubyists. Their system used vCards for almost everything.  Dissatisfied with the vPIM library they set out to write their own vCard parser/builder.

It was decided to release this library as open source to give something back to the Ruby community.

## FAQ

* **Why this name?**

  Well if Richard Branson can start a business that's called... okay, okay, see here: [Urban dictionary: vcard](http://www.urbandictionary.com/define.php?term=vcard)

* **Why did you rebase all the history to one big commit?**

  When we started with the development we made a mistake in our judgement: we used real life data in our tests; since that is obviously the best way to make sure everything works well with data that we can actually expect to encounter, right? It made sense at the time, and it worked well until we realised that we could never share this library with the outside world as it was.

  To protect the privacy of the people depicted in our test data, we decided to simply remove all sensitive information from the git repository. This was by far the easiest way to accomplish that.

  This means that using `git blame` will always tell you to use @tijn as your scapegoat. This is okay, it is likely that he is the source of faults in this library anyway. You should direct your complaints to him.

* **How does it perform?**

  It could be faster, but then again, it could also be slower.

  It is very reliable in that it will do the right thing (in my subjective opinion). It will not, for example, break the line-folding when you change a field or mix up the 2.1- and 3.0-ways of indicating labels for telephone numbers. It has been used to (de-)serialize and manipulate the contact information of millions of people.
