package campweb.services.impl;

import org.springframework.security.core.userdetails.UserDetails;

import campweb.entities.UserEntity;

public class CustomUserDetail implements UserDetails {
    private UserEntity userEntity;

    public CustomUserDetail(UserEntity userEntity) {
        this.userEntity = userEntity;
    }

    @Override
    public String getUsername() {
        return userEntity.getUsername();
    }

    public String getEmail() {
        return userEntity.getEmail(); // Assuming UserEntity has a getEmail method
    }


    public String getPhoneNumber() {
        return userEntity.getPhoneNumber(); // Assuming UserEntity has a getPhoneNumber method
    }

    @Override
    public String getPassword() {
        return userEntity.getPassword();
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public java.util.Collection<? extends org.springframework.security.core.GrantedAuthority> getAuthorities() {
        return java.util.Collections.emptyList();
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
    
}
