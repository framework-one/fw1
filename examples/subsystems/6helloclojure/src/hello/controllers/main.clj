(ns hello.controllers.main
  (:require [hello.services.greeter :as greet]))

(defn call-method [rc cfc method & args]
  (let [pc (:pc rc)]
    (.call cfc pc method (into-array Object args))))

(defn get-bean [rc bean-name]
  (let [ioc (:ioc rc)]
    (call-method rc ioc "getBean" bean-name)))

(defn default [rc]
  (-> rc
      (assoc :greeting     (greet/hello (:name rc "anonymous")))
      (assoc :cfmlgreeting (call-method rc (get-bean rc "test") "greet" "CFML"))))

(defn do-redirect [rc]
  (assoc rc :redirect {:action "main.default" :queryString "name=Mr. Redirect"}))

(defn stop-it [rc]
  (assoc rc :abort :controller :view {:action "main.stopped"}))

(defn json [rc]
  (assoc rc :render {:type :json :data {:a 1 :b "two" :c [3 4 5]}}))
