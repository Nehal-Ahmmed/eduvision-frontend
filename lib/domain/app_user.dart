class AppUser {
  final String username;
  final String email;
  final String? token;

  AppUser({required this.username, required this.email, this.token});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      username: json['username'],
      email: json['email'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'email': email, 'token': token};
  }
}
