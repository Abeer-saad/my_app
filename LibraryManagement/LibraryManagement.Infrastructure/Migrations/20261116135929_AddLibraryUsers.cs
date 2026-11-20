using Microsoft.EntityFrameworkCore.Migrations;
#nullable disable
namespace LibraryManagement.Infrastructure.Migrations
{
    public partial class AddLibraryUsers : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Adopt an existing Users table without removing or resetting accounts.
            migrationBuilder.Sql(@"
IF OBJECT_ID(N'[dbo].[Users]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id] int IDENTITY NOT NULL CONSTRAINT [PK_Users] PRIMARY KEY,
        [Name] nvarchar(max) NOT NULL,
        [Email] nvarchar(450) NOT NULL,
        [Username] nvarchar(450) NOT NULL,
        [PasswordHash] nvarchar(max) NOT NULL);
END
ELSE
BEGIN
    IF EXISTS (SELECT 1 FROM [dbo].[Users] WHERE LEN([Email]) > 450 OR LEN([Username]) > 450)
        THROW 50001, 'Existing account values are too long for unique indexes.', 1;
    IF EXISTS (SELECT [Email] FROM [dbo].[Users] GROUP BY [Email] HAVING COUNT(*) > 1)
        THROW 50002, 'Duplicate emails must be resolved without deleting accounts.', 1;
    IF EXISTS (SELECT [Username] FROM [dbo].[Users] GROUP BY [Username] HAVING COUNT(*) > 1)
        THROW 50003, 'Duplicate usernames must be resolved without deleting accounts.', 1;
    ALTER TABLE [dbo].[Users] ALTER COLUMN [Email] nvarchar(450) NOT NULL;
    ALTER TABLE [dbo].[Users] ALTER COLUMN [Username] nvarchar(450) NOT NULL;
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = N'IX_Users_Email')
    CREATE UNIQUE INDEX [IX_Users_Email] ON [dbo].[Users] ([Email]);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = N'IX_Users_Username')
    CREATE UNIQUE INDEX [IX_Users_Username] ON [dbo].[Users] ([Username]);
");
        }
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Never drop a table that may have been created by another project version.
            throw new System.NotSupportedException("Automatic rollback is disabled to preserve existing accounts. Review a forward migration instead.");
        }
    }
}
