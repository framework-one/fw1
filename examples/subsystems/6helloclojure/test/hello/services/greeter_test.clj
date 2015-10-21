(ns hello.services.greeter-test
  (:require [clojure.test :refer :all]
            [hello.services.greeter :refer :all]))

(deftest hello-test
  (is (= "Hello Person!" (hello "Person"))))
