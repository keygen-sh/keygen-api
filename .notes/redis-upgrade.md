Enable maintenance mode and scale down dynos:

```
heroku maintenance:on
heroku ps:scale web=0 worker=0
```

Fork Redis:

```
heroku config:get REDIS_URL
heroku addons:create heroku-redis:premium-5 --fork {{PREV_REDIS_URL}
```

Wait until ready:

```
heroku addons:info {{NEXT_REDIS_NAME}}
```

Promote Redis:

```
heroku redis:promote {{NEXT_REDIS_NAME}}
```

Update key eviction policy:

```
heroku redis:maxmemory {{NEXT_REDIS_NAME}} --policy volatile-lru
```

Confirm database is correct:

```
heroku redis:info
```

Scale up dynos and disable maintenance mode:

```
heroku ps:scale web=1 worker=2
heroku maintenance:off
```

Deprovisioning the prev Redis:

```
heroku addons:destroy {{PREV_REDIS_NAME}}
```
