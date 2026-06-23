import { api } from "@/lib/api";

interface SocialPost {
  id: number;
  platform: string;
  content: string;
  status: string;
  tweet_id: string | null;
  published_at: string | null;
  engagement: Record<string, number> | null;
}

export default async function SocialPage() {
  let posts: SocialPost[] = [];
  try {
    posts = await api.get<SocialPost[]>("/social/posts", { cache: "no-store" });
  } catch {}

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Social Media</h1>
      <div className="space-y-3">
        {posts.map((post) => (
          <div key={post.id} className="bg-card rounded-lg border border-border p-4">
            <p className="mb-2">{post.content}</p>
            <div className="flex gap-4 text-xs text-muted">
              <span>Status: {post.status}</span>
              <span>Platform: {post.platform}</span>
              {post.engagement && <span>Likes: {post.engagement.likes || 0}</span>}
            </div>
          </div>
        ))}
        {posts.length === 0 && <p className="text-muted">No posts yet.</p>}
      </div>
    </div>
  );
}
