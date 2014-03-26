<!--- TODO: Date and version -->
# March 2014 (v)
<!--- TODO: Check on this version number -->
- Drop support for Redis < 2.2.6
- Add backends for Redis, Redis::Distributed and Riak
- FIXED: counters never expire if created with increment or decrement methods

# Previous
<!--- TODO: Fill in -->


# TODO/BUGS(?):
- clear_storage for counters
- clear_* method tests
- hook AR reload method to clear_storage?
- add a way (maybe using MR) to expire keys in Riak
- Riak exists doesn't check expiry
- Remove backend methods that are not required
- Remove pry
- When deleting objects on the Riak backend, also delete the expiry
- Now, counters always have their expiry reset
- Test del, delc on multi
- Test multi with other mixtures of backends
