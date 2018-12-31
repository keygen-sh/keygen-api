Create a new follower database:
```
heroku addons:create heroku-postgresql:standard-2 --follow HEROKU_POSTGRESQL_OLIVE_URL
heroku pg:wait
```

Wait until Behind By < 200 commits:
```
heroku pg:info
```

Enable maintenance mode and scale down dynos:
```
heroku maintenance:on
heroku ps:scale web=0 worker=0
```

Wait until follower is caught up (Behind By = 0 commits):
```
heroku pg:info
```

Move the new database from a follower to a primary:
```
heroku pg:unfollow HEROKU_POSTGRESQL_MAUVE_URL
```

Promote the new database:
```
heroku pg:promote HEROKU_POSTGRESQL_MAUVE_URL
```

Disable maintenance mode and scale up dynos:
```
heroku ps:scale web=3 worker=1
heroku maintenance:off
```

Confirm database is correct:
```
heroku pg:info
```

Update pgbouncer:
- max pool size to `25`
- min pool size to `10`
- reserve size to `10`
- max client conns to `500`

Deprovisioning the old database:
```
heroku addons:destroy HEROKU_POSTGRESQL_OLIVE_URL
```