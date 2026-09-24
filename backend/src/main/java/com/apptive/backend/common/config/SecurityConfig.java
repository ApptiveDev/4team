package com.apptive.backend.common.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.context.SecurityContextHolderFilter;
import org.springframework.security.web.SecurityFilterChain;

import com.apptive.backend.common.auth.RestAccessDeniedHandler;
import com.apptive.backend.common.auth.RestAuthenticationEntryPoint;
import com.apptive.backend.common.web.TraceIdFilter;

@Configuration
public class SecurityConfig {

	@Bean
	public SecurityFilterChain securityFilterChain(
		HttpSecurity http,
		RestAuthenticationEntryPoint authenticationEntryPoint,
		RestAccessDeniedHandler accessDeniedHandler,
		TraceIdFilter traceIdFilter
	) throws Exception {
		http
			.addFilterBefore(traceIdFilter, SecurityContextHolderFilter.class)
			.csrf(csrf -> csrf.disable())
			.formLogin(form -> form.disable())
			.httpBasic(basic -> basic.disable())
			.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
			.exceptionHandling(exceptions -> exceptions
				.authenticationEntryPoint(authenticationEntryPoint)
				.accessDeniedHandler(accessDeniedHandler))
			.authorizeHttpRequests(authorize -> authorize
				.requestMatchers(HttpMethod.GET, "/api/v1/health").permitAll()
				.requestMatchers(HttpMethod.POST, "/api/v1/users").permitAll()
				.anyRequest().authenticated());

		return http.build();
	}
}
