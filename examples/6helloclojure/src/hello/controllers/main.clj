(ns hello.controllers.main
  (:require [hello.services.greeter :as greet]))

(defn default [rc]
  (assoc rc :greeting (greet/hello (:name rc "anonymous"))))

(defn do-redirect [rc]
  (assoc rc :redirect {:action "main.default" :queryString "name=Mr. Redirect"}))

(defn stop-it [rc]
  (assoc rc :abort :controller :view {:action "main.stopped"}))

(defn json [rc]
  (assoc rc :render {:type :json :data {:a 1 :b "two" :c [3 4 5]}}))
