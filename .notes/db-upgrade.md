Create a new follower database:

```
heroku addons:create heroku-postgresql:standard-2 --follow HEROKU_POSTGRESQL_MAUVE_URL
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

If needed, upgrade the database:

```
heroku pg:upgrade HEROKU_POSTGRESQL_TEAL
heroku pg:wait
```

Wait until database is upgraded (takes ~20m):

```
heroku pg:info
```

Move the new database from a follower to a primary:

```
heroku pg:unfollow HEROKU_POSTGRESQL_TEAL
```

Promote the new database:

```
heroku pg:promote HEROKU_POSTGRESQL_TEAL
```

Confirm database is correct:

```
heroku pg:info
```

Disable preboot, scale up dynos and disable maintenance mode:

```
heroku features:disable preboot
heroku ps:scale web=2 worker=2
heroku maintenance:off
heroku features:enable preboot
```

Configure maintenance windows to match:

```
heroku pg:maintenance:window postgresql-trapezoidal-99710 'Saturday 07:00'
```

Deprovisioning the old database:

```
heroku addons:destroy HEROKU_POSTGRESQL_MAUVE
```
