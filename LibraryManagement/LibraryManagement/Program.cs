using LibraryManagement.Application.Services;
using LibraryManagement.Application.Services.Base;
using LibraryManagement.Infrastructure.Data;
using LibraryManagement.Infrastructure.Repositories;
using LibraryManagement.Infrastructure.Repositories.Base;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;

var builder=WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<ApplicationDbContext>(o=>o.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(o=>{o.LoginPath="/Account/Login";o.AccessDeniedPath="/Account/AccessDenied";o.ExpireTimeSpan=TimeSpan.FromMinutes(30);o.Cookie.HttpOnly=true;o.SlidingExpiration=true;});
builder.Services.AddScoped<IBookRepository,BookRepository>();builder.Services.AddScoped<ICategoryRepository,CategoryRepository>();builder.Services.AddScoped<ICustomerRepository,CustomerRepository>();builder.Services.AddScoped<IBorrowingRepository,BorrowingRepository>();builder.Services.AddScoped<IUnitOfWork,UnitOfWork>();
builder.Services.AddScoped<IBookService,BookService>();builder.Services.AddScoped<ICategoryService,CategoryService>();builder.Services.AddScoped<ICustomerService,CustomerService>();builder.Services.AddScoped<IBorrowingService,BorrowingService>();
var app=builder.Build();if(!app.Environment.IsDevelopment()){app.UseExceptionHandler("/Home/Error");app.UseHsts();}app.UseHttpsRedirection();app.UseStaticFiles();app.UseRouting();app.UseAuthentication();app.UseAuthorization();app.MapControllerRoute(name:"default",pattern:"{controller=Home}/{action=Index}/{id?}");app.Run();
