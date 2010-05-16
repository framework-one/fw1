<?xml version="1.0" encoding="utf-8"?>
<beans>

	<bean id="departmentService" class="userManager.services.Department" singleton="true">
	</bean>

	<bean id="roleService" class="userManager.services.role" singleton="true">
	</bean>

	<bean id="userService" class="userManager.services.User" singleton="true">
		<argument name="departmentService">
			<ref bean="departmentService" />
		</argument>
		<argument name="roleService">
			<ref bean="roleService" />
		</argument>
	</bean>

	<!--
		<bean> - Define a bean with an id (referenced using that value), the class path
				(can use a mapping), and whether its a singleton or not (boolean)

		<argument> - Defines a constructor argument for a bean, name must match CFC argument name

		<property> - Defines a property for a bean that is set via the set{propertyName} method

		<ref> - Defines a reference to an existing configured bean, the name attribute
				would be the id of the bean being referenced

		<array> - Define an array for a property or argument

		<struct> - Define a structure for a property or argument

		<element> - Define an element for an array or structure, you can define the value
					within the element using a value tag (<element><value>some value</value></element>)
					or using a value attribute, you can mix and match if you like

		<value> - Define a value for an element in a structure or in an array


		Examples:

		<property values="names">
			<array>
				<value>Moe</value>
				<element value="Curly" />
				<element>
					<value>Joe</value>
				</element>
				<element>
					<array>
						<element value="John" />
					</array>
				</element>
			</array>
		</property>

		<argument name="states">
			<struct>
				<element key="NY" value="New York"/>
				<element key="NJ">
					<value>New Jersey</value>
				</element>
			</struct>
		</argument>
	-->

</beans>