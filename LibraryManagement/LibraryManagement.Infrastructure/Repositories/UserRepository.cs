using LibraryManagement.Domain.Models;
using LibraryManagement.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
namespace LibraryManagement.Infrastructure.Repositories;
public interface IUserRepository
{
    Task<User?> GetByEmailAsync(string email);
    Task<bool> ExistsAsync(string email, string username);
    Task AddAsync(User user);
}
public class UserRepository(ApplicationDbContext context) : IUserRepository
{
    public Task<User?> GetByEmailAsync(string email) => context.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Email == email);
    public Task<bool> ExistsAsync(string email, string username) => context.Users.AnyAsync(u => u.Email == email || u.Username == username);
    public async Task AddAsync(User user)
    {
        context.Users.Add(user);
        await context.SaveChangesAsync();
    }
}
