(ns hello.controllers.main-test
  (:require [clojure.test :refer :all]
            [hello.controllers.main :refer :all]))

(deftest default-item-test
  (testing "default name is anonymous"
    (is (= "Hello anonymous!" (-> {} default :greeting))))
  (testing "default adds Hello and !"
    (is (= "Hello Clojure!" (-> {:name "Clojure"} default :greeting)))))
