using Microsoft.AspNetCore.Identity;
using LibraryManagement.Application.DTOs;
using LibraryManagement.Domain.Models;
using LibraryManagement.Infrastructure.Repositories;
namespace LibraryManagement.Application.Services;
public interface IUserService
{
    Task<UserDto?> LoginAsync(LoginDto dto);
    Task<UserDto> RegisterAsync(RegisterDto dto);
}
public class UserService(IUserRepository repository) : IUserService
{
    private readonly PasswordHasher<User> _hasher = new();
    private static UserDto Map(User user) => new() { Id = user.Id, Name = user.Name, Email = user.Email, Username = user.Username };
    public async Task<UserDto> RegisterAsync(RegisterDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        var username = dto.Username.Trim();
        if (string.IsNullOrWhiteSpace(dto.Name) || username.Length == 0 || dto.Password.Length < 6)
            throw new InvalidOperationException("Enter a name, username and password of at least 6 characters.");
        if (await repository.ExistsAsync(email, username))
            throw new InvalidOperationException("Email or username already exists.");
        var user = new User { Name = dto.Name.Trim(), Email = email, Username = username };
        user.PasswordHash = _hasher.HashPassword(user, dto.Password);
        await repository.AddAsync(user);
        return Map(user);
    }
    public async Task<UserDto?> LoginAsync(LoginDto dto)
    {
        var user = await repository.GetByEmailAsync(dto.Email.Trim().ToLowerInvariant());
        if (user is null) return null;
        try
        {
            var result = _hasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
            return result == PasswordVerificationResult.Failed ? null : Map(user);
        }
        catch (FormatException) { return null; }
    }
}
